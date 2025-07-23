/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { BlockNoteSchema, defaultBlockSpecs, filterSuggestionItems } from "@blocknote/core";
import { BlockNoteView } from "@blocknote/mantine";
import { getDefaultReactSlashMenuItems, SuggestionMenuController, useCreateBlockNote } from "@blocknote/react";
import { dummyBlockSpec, getDefaultOpenProjectSlashMenuItems, openProjectWorkPackageBlockSpec } from "op-blocknote-extensions";
import { useEffect, useState } from "react";
import { HocuspocusProvider } from "@hocuspocus/provider";
import * as Y from 'yjs';

export interface OpBlockNoteContainerProps {
  inputField: HTMLInputElement;
  inputText?: string;
  hocuspocusUrl: string;
  hocuspocusAccessToken: string;
  userName: string;
  documentId: string;
}

type OpTheme = "light" | "dark";

const schema = BlockNoteSchema.create({
  blockSpecs: {
    ...defaultBlockSpecs,
    openProjectWorkPackage: openProjectWorkPackageBlockSpec,
    dummy: dummyBlockSpec,
  },
});

const detectTheme = (): OpTheme => {
  if (document.body.getAttribute('data-color-mode') === 'dark') {
    return 'dark';
  }
  return 'light';
};

export default function OpBlockNoteContainer({ inputField,
                                               inputText,
                                               userName,
                                               hocuspocusUrl,
                                               hocuspocusAccessToken,
                                               documentId }: OpBlockNoteContainerProps) {
  const [isLoading, setIsLoading] = useState(true);

  let collaboration: any;
  const collaborationEnabled: boolean = Boolean(hocuspocusUrl && documentId && hocuspocusAccessToken && userName);
  let provider: HocuspocusProvider | null = null;

  if(collaborationEnabled) {
    const doc = new Y.Doc()
    provider = new HocuspocusProvider({
      url: hocuspocusUrl,
      name: documentId,
      token: hocuspocusAccessToken,
      document: doc
    });
    const cursorColor = '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
    collaboration = {
      provider,
      fragment: doc.getXmlFragment("document-store"),
      user: {
        name: userName,
        color: cursorColor,
      },
      showCursorLabels: "activity"
    }
  }
  const editor = useCreateBlockNote(collaboration ? { collaboration, schema } : { schema });
  type EditorType = typeof editor;

  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      ...getDefaultOpenProjectSlashMenuItems(editor),
    ];
  };

  useEffect(() => {
    async function prepareEditor() {
      if(collaborationEnabled && provider) {
        provider.on('synced', async () => {
          console.log('BlockNote collaboration synced');
          setIsLoading(false);
        });
        provider.on('disconnect', () => {
          console.error('BlockNote collaboration disconnected');
        });
      } else {
        const blocks = await editor.tryParseMarkdownToBlocks(inputText || "");
        editor.replaceBlocks(editor.document, blocks);
        setIsLoading(false);
      }
    }
    void prepareEditor();
    return  ()  => {
      if (provider) {
        provider.destroy();
      }
    };
  }, []);

  return (
    <>
      {isLoading ? <div>Loading...</div>
        :
        <BlockNoteView
          editor={editor}
          theme={detectTheme()}
          onChange={async (editor) => {
            const content = await editor.blocksToMarkdownLossy();
            inputField.value = content;
          }}
        >
          <SuggestionMenuController
            triggerCharacter="/"
            getItems={async (query: string) => filterSuggestionItems(getCustomSlashMenuItems(editor), query)}
          />
        </BlockNoteView>
      }
    </>
  );
}
